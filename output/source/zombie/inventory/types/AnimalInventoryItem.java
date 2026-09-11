// Decompiled with Zomboid Decompiler v0.3.2 using Vineflower.
package zombie.inventory.types;

import java.io.IOException;
import java.nio.ByteBuffer;
import zombie.UsedFromLua;
import zombie.characters.IsoPlayer;
import zombie.characters.animals.IsoAnimal;
import zombie.characters.skills.PerkFactory.Perks;
import zombie.core.Core;
import zombie.core.Translator;
import zombie.core.textures.Texture;
import zombie.inventory.InventoryItem;
import zombie.iso.IsoWorld;
import zombie.scripting.objects.Item;
import zombie.scripting.objects.ItemType;
import zombie.ui.ObjectTooltip;
import zombie.ui.UIFont;
import zombie.ui.ObjectTooltip.Layout;
import zombie.ui.ObjectTooltip.LayoutItem;
import zombie.util.StringUtils;

@UsedFromLua
public class AnimalInventoryItem extends InventoryItem {
    private IsoAnimal animal;
    private String animalName;

    public AnimalInventoryItem(String module, String name, String type, String tex) {
        super(module, name, type, tex);
        this.itemType = ItemType.ANIMAL;
    }

    public AnimalInventoryItem(String module, String name, String type, Item item) {
        super(module, name, type, item);
        this.itemType = ItemType.ANIMAL;
    }

    public void update() {
        if (this.getContainer() != null) {
            if (this.animal != null) {
                this.animal.container = this.getContainer();
                this.animal.square = null;
                this.animal.setCurrent(null);
                this.animal.update();
            }
        }
    }

    public void DoTooltip(ObjectTooltip tooltipUI, Layout layout) {
        tooltipUI.render();
        UIFont font = tooltipUI.getFont();
        int lineSpacing = tooltipUI.getLineSpacing();
        int y = 5;
        LayoutItem item = layout.addItem();
        item.setLabel(Translator.getText("IGUI_AnimalType", new Object[0]) + ":", 1.0F, 1.0F, 0.8F, 1.0F);
        item.setValue(Translator.getText("IGUI_AnimalType_" + this.animal.getAnimalType(), new Object[0]), 1.0F, 1.0F, 1.0F, 1.0F);
        item = layout.addItem();
        item.setLabel(Translator.getText("UI_characreation_gender", new Object[0]) + ":", 1.0F, 1.0F, 0.8F, 1.0F);
        String text = Translator.getText("IGUI_Animal_Female", new Object[0]);
        if (!this.animal.isFemale()) {
            text = Translator.getText("IGUI_Animal_Male", new Object[0]);
        }

        item.setValue(text, 1.0F, 1.0F, 1.0F, 1.0F);
        item = layout.addItem();
        item.setLabel(Translator.getText("IGUI_char_Age", new Object[0]) + ":", 1.0F, 1.0F, 0.8F, 1.0F);
        item.setValue(this.animal.getAgeText(Core.getInstance().animalCheat, IsoPlayer.getInstance().getPerkLevel(Perks.Husbandry)), 1.0F, 1.0F, 1.0F, 1.0F);
        item = layout.addItem();
        item.setLabel(Translator.getText("IGUI_Animal_Appearance", new Object[0]) + ":", 1.0F, 1.0F, 0.8F, 1.0F);
        item.setValue(this.animal.getAppearanceText(Core.getInstance().animalCheat), 1.0F, 1.0F, 1.0F, 1.0F);
        item = layout.addItem();
        item.setLabel(Translator.getText("IGUI_XP_Health", new Object[0]) + ":", 1.0F, 1.0F, 0.8F, 1.0F);
        item.setValue(this.animal.getHealthText(Core.getInstance().animalCheat, IsoPlayer.getInstance().getPerkLevel(Perks.Husbandry)), 1.0F, 1.0F, 1.0F, 1.0F);
        if (Core.getInstance().animalCheat) {
            item = layout.addItem();
            item.setLabel("[DEBUG] Stress:", 1.0F, 1.0F, 0.8F, 1.0F);
            item.setValue(Math.round(this.animal.getStress()) + "", 1.0F, 1.0F, 1.0F, 1.0F);
            if (this.animal.heldBy != null) {
                item = layout.addItem();
                item.setLabel("[DEBUG] Acceptance:", 1.0F, 1.0F, 0.8F, 1.0F);
                item.setValue(Math.round(this.animal.getAcceptanceLevel(this.animal.heldBy)) + "", 1.0F, 1.0F, 1.0F, 1.0F);
            }
        }
    }

    public boolean finishupdate() {
        return false;
    }

    public void initAnimalData() {
        if (!StringUtils.isNullOrEmpty(this.animal.getCustomName())) {
            this.animalName = this.animal.getCustomName();
        } else {
            this.animalName = Translator.getText("IGUI_Breed_" + this.animal.getBreed().getName(), new Object[0])
                + " "
                + Translator.getText("IGUI_AnimalType_" + this.animal.getAnimalType(), new Object[0]);
        }

        this.setName(this.animalName);
        this.setWeight(this.animal.adef.baseEncumbrance * this.animal.getAnimalSize());
        this.setActualWeight(this.getWeight());
        String icon = this.animal.getInventoryIconTextureName();
        if (!StringUtils.isNullOrEmpty(icon)) {
            this.setIcon(Texture.getSharedTexture(icon));
        }

        if (this.animal.mother != null) {
            this.animal.attachBackToMother = this.animal.mother.animalId;
        }
    }

    public IsoAnimal getAnimal() {
        return this.animal;
    }

    public void setAnimal(IsoAnimal animal) {
        this.animal = animal;
        this.animal.setItemID(this.id);
        this.initAnimalData();
    }

    public void save(ByteBuffer output, boolean net) throws IOException {
        super.save(output, net);
        this.animal.save(output, net, false);
    }

    public void load(ByteBuffer input, int worldVersion) throws IOException {
        super.load(input, worldVersion);
        this.animal = new IsoAnimal(IsoWorld.instance.getCell());
        this.animal.load(input, worldVersion, false);
        this.initAnimalData();
    }

    public String getCategory() {
        return "Animal";
    }

    public boolean shouldUpdateInWorld() {
        return true;
    }
}
